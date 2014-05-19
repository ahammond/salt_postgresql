{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}
  - postgresql.check_postgres

general_postgresql_tools:
  pkg.installed:
    - pkgs:
      - postgresql_autodoc
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}

{% set reorg_rpm_filename = "pg_reorg-1.1.9-1.pg92.rhel6.x86_64.rpm" %}
{% set reorg_rpm_url = "http://pgfoundry.org/frs/download.php/3560/%s" % ( reorg_rpm_filename ) %}
pg_reorg:
  pkg.installed:
    - sources:
      - pg_reorg: {{ reorg_rpm_url }}
