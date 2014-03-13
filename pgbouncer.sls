{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}
  - postgresql.collectd

/var/log/pgbouncer:
  file.directory:
    - user: pgbouncer
    - group: adm
    - mode: 755
    - require:
      - user: pgbouncer

{% set userlist_txt = '/etc/pgbouncer/userlist.txt' %}
{{ userlist_txt }}:
  file.managed:
    - source: salt://postgresql/files{{ userlist_txt }}
    - template: jinja
    - user: pgbouncer
    - mode: 600
    - user_info: {{ pillar['postgresql']['users'] }}
    - require:
      - user: pgbouncer

pgbouncer:
  user.present:
    - system: True
    - gid_from_name: True
    - password: !
    - shell: /bin/sh
    - home: /home/pgbouncer
    - createhome: True
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}
      - file: /var/log/pgbouncer

{% for pgbouncer_name, pgbouncer_config in pillar['postgresql'].get('pgbouncers', {}) | dictsort %}
{%   set pgbouncer_ini = '/etc/pgbouncer/' + pgbouncer_name + '.ini' %}
{{ pgbouncer_ini }}:
  file.managed:
    - source: salt://postgresql/files/etc/pgbouncer/pgbouncer.ini
    - template: jinja
    - user: pgbouncer
    - mode: 644
    - databases: {{ pillar['postgresql']['databases'] }}
    - pgbouncer_name: {{ pgbouncer_name }}
    - pgbouncer_config: {{ pgbouncer_config }}
    - require:
      - pkg: pgbouncer
      - user: pgbouncer

{%   set pgbouncer_init = '/etc/init.d/' + pgbouncer_name %}
{{ pgbouncer_init }}:
  file.managed:
    - source: salt://postgresql/files/etc/init.d/pgbouncer
    - pgbouncer_name: {{ pgbouncer_name }}
    - mode: 755
    - require:
      - pkg: pgbouncer

{%   set pgbouncer_sysconfig = '/etc/sysconfig/' + pgbouncer_name %}
{{ pgbouncer_sysconfig }}:
  file.managed:
    - source: salt://postgresql/files/etc/sysconfig/pgbouncer
    - template: jinja
    - pgbouncer_name: {{ pgbouncer_name }}
    - require:
      - pkg: pgbouncer

{{ pgbouncer_name }}_service:
  service.running:
    - name: {{ pgbouncer_name }}
    - enable: True
    - reload: True
    - require:
      - pkg: pgbouncer
      - user: pgbouncer
      - file: {{ pgbouncer_init }}
      - file: {{ pgbouncer_sysconfig }}
    - watch:
      - file: {{ pgbouncer_ini }}
      - file: {{ userlist_txt }}
{% endfor %}
