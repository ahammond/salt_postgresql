include:
  - postgresql.ppa

postgresql-client-9.2:
  pkg.installed:
    - require:
      - cmd: update_apt
