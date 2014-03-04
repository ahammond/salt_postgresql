{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}

{{ postgresql.server_pkg }}:
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

postgresql92-contrib:
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

{% if postgresql.initdb %}
# CentOS requires us to manually run initdb, which is probably a good idea, but... mildly annoying.
service postgresql-9.2 initdb:
  cmd.run:
    - unless: test -d {{ postgresql.pgdata }}/base
    - require:
      - pkg: {{ postgresql.pkg }}
      - file: {{ postgresql.log_dir }}
      - file: {{ postgresql.pgdata }}
{% endif %}

{{ postgresql.conf }}:
  file.managed:
    - source: salt://postgresql/files{{ postgresql.conf }}
    - template: jinja
    - user: postgres
    - group: postgres
    - require:
      - pkg: {{ postgresql.server_pkg }}

{{ postgresql.log_dir }}:
  file.directory:
    - user: postgres
    - group: postgres
    - dir_mode: 755

{% set trim_log_cron = "find %s -name '*.log' -mtime +%d -delete > /dev/null 2>&1" % (postgresql.log_dir, postgresql.log_retention_days) %}
{{ trim_log_cron }}:
  cron.present:
    - user: postgres
    - minute: random
    - hour: 7
    - require:
      - pgk: {{ postresql.server_pkg }}

{% set trim_wal_archive = "find %s -mtime +%d -delete > /dev/null 2>&1" % (postgresql.wal_archive, postgresql.wal_archive_retention_days) %}
{{ trim_wal_archive }}:
  cron.present:
    - user: postgres
    - minute: random
    - hour: '*/4'
    - require:
      - pgk: {{ postresql.server_pkg }}

{{ postgresql.service_name }}:
  service.running:
    - reload: True
    - require:
      - pkg: {{ postgresql.server_pkg }}
      - cron: {{ trim_log_cron }}
      - cron: {{ trim_wal_archive }}
    - watch:
      - file: {{ postgresql.conf }}
