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

{% set pgbouncer_ini = '/etc/pgbouncer/pgbouncer.ini' %}
{{ pgbouncer_ini }}:
  file.managed:
    - source: salt://postgresql/files{{ pgbouncer_ini }}
    - template: jinja
    - user: pgbouncer
    - mode: 644
    - databases: {{ pillar['postgresql']['databases'] }}
    - pgbouncer_config: {{ pillar['postgresql']['pgbouncer'] }}
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
    - shell: /sbin/nologin
    - home: /home/pgbouncer
    - createhome: True
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}
      - file: /var/log/pgbouncer
  service.running:
    - enable: True
    - reload: True
    - require:
      - pkg: pgbouncer
      - user: pgbouncer
    - watch:
      - file: {{ pgbouncer_ini }}
      - file: {{ userlist_txt }}