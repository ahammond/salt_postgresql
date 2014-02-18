{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}

{{ postgresql.conf }}:
  file.managed:
    - source: salt://postgresql/files{{ postgresql.conf }}
    - template: jinja
    - user: postgres
    - group: postgres
    - require:
      - pkg: {{ postgresql.pkg }}

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

{% set trim_wal_archive = "find %s -mtime +%d -delete > /dev/null 2>&1" % (postgresql.wal_archive, postgresql.wal_archive_retention_days) %}
{{ trim_wal_archive }}:
  cron.present:
    - user: postgres
    - minute: random
    - hour: '*/4'

postgresql:
  service.running:
    - require:
      - pkg: {{ postgresql.pkg }}
      - cron: {{ trim_log_cron }}
      - cron: {{ trim_wal_archive }}
    - watch:
      - file: {{ postgresql.conf }}
