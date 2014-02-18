{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - {{ postgresql.repository }}

{{ postgresql.client_pkg }}:
  pkg.installed:
    - require:
      - pkgrepo: {{ postgresql.pgdg_repo }}
