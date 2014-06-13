{% from 'postgresql/map.jinja' import postgresql with context %}
{% from 'zabbix/map.jinja' import zabbix with context %}

include:
  - {{ postgresql.repository }}
  - postgresql.collectd
  - zabbix

postgresql_packages:
  pkg.installed:
    - pkgs:
      - {{ postgresql.server_pkg }}
      - postgresql92-contrib
      - postgresql92-odbc
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

postgresql92-contrib:
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

postgres_user:
  user.present:
    - name: {{ postgresql.user }}
    - system: True
    - gid_from_name: True
    - password: \*
    - home: {{ postgresql.home }}
    - require:
      - pkg: postgresql_packages

{{ postgresql.home }}:
  file.directory:
    - user: {{ postgresql.user }}
    - group: postgres
    - makedirs: True
    - require:
      - pkg: postgresql_packages
      - user: {{ postgresql.user }}

{{ postgresql.home }}/.pgpass:
  file.managed:
    - source: salt://postgresql/files/home/pgpass
    - template: jinja
    - user: {{ postgresql.user }}
    - group: postgres
    - mode: 600
    - unix_user: postgres
    - require:
      - file: {{ postgresql.home }}
      - user: {{ postgresql.user }}

{{ zabbix.conf_dir }}/postgresql.conf:
  file.managed:
    - source: salt://postgresql/files/etc/zabbix/zabbix_agentd.d/postgresql.conf
    - template: jinja

{% if postgresql.initdb %}
# CentOS requires us to manually run initdb, which is probably a good idea, but... mildly annoying.
service postgresql-9.2 initdb:
  cmd.run:
    - unless: test -d {{ postgresql.pgdata }}/base
    - require:
      - pkg: postgresql_packages
      - user: {{ postgresql.user }}
      - file: {{ postgresql.log_dir }}
      - file: {{ postgresql.pgdata }}
{% endif %}

{{ postgresql.conf }}:
  file.managed:
    - source: salt://postgresql/files{{ postgresql.conf }}
    - template: jinja
    - user: {{ postgresql.user }}
    - group: postgres
    - require:
      - pkg: postgresql_packages
      - user: {{ postgresql.user }}

{{ postgresql.log_dir }}:
  file.directory:
    - user: {{ postgresql.user }}
    - group: postgres
    - dir_mode: 755
    - require:
      - pkg: postgresql_packages
      - user: {{ postgresql.user }}

{% set trim_log_cron = "find %s -name '*.log' -mtime +%d -delete > /dev/null 2>&1" % (postgresql.log_dir, postgresql.log_retention_days) %}
{{ trim_log_cron }}:
  cron.present:
    - user: {{ postgresql.user }}
    - minute: random
    - hour: 7
    - require:
      - file: {{ postgresql.log_dir }}
      - user: {{ postgresql.user }}

{{ postgresql.wal_archive }}:
  file.directory:
    - user: {{ postgresql.user }}
    - group: postgres
    - dir_mode: 755
    - makedirs: True
    - require:
      - pkg: postgresql_packages
      - user: {{ postgresql.user }}

{% set trim_wal_archive = "find %s -mtime +%d -delete > /dev/null 2>&1" % (postgresql.wal_archive, postgresql.wal_archive_retention_days) %}
{{ trim_wal_archive }}:
  cron.present:
    - user: {{ postgresql.user }}
    - minute: random
    - hour: '*/4'
    - require:
      - file: {{ postgresql.wal_archive }}

{{ postgresql.service_name }}:
  service.running:
    - enable: True
    - reload: True
    - require:
      - pkg: postgresql_packages
      - cron: {{ trim_log_cron }}
      - cron: {{ trim_wal_archive }}
    - watch:
      - file: {{ postgresql.conf }}

{#
## For every database, if this is the master, handle extensions, etc
#}
{% for dbname, blob in pillar.get('postgresql', {}).get('databases', {}) | dictsort %}
{%   if blob.get('master', {}).get('host', '') in grains.get('ipv4', '') %}
{%     set db_port = blob.get('master', {}).get('port', 5432) %}
# I'm the master for this DB, so... manage some stuff.
{%     for user, user_blob in pillar['postgresql'].get('users', {}) | dictsort %}
{%       if user in blob.get('users', []) %}
postgres_{{ db_port }}_user_{{ user }}:
  postgres_user.present:
    - require:
      - service: {{ postgresql.service_name }}
    - db_port: {{ db_port }}
    - name: {{ user }}
    - password: {{ user_blob['password'] }}
{%         for k, v in user_blob.get('permissions', {}) | dictsort %}
    - {{ k }}: {{ v }}
{%         endfor %}
{%       endif %}
{%     endfor %}
{%   endif %}
{% endfor %}
