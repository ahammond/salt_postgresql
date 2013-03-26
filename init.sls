include:
  - postgresql.ppa

postgresql_packages:
  pkg.installed:
    - pkgs:
      - libpq5
      - libpq-dev
      - postgresql-client-9.2
      - postgresql-9.2
      - postgresql-server-dev-9.2
      - pgdg-keyring
    - require:
      - pkgrepo: {{ ppa }}
      - cmd: update_apt

{% set postgresql_conf = '/etc/postgresql/9.2/main/postgresql.conf' %}
{{ postgresql_conf }}:
  file.managed:
    - source: salt://postgresql/files{{ postgresql_conf }}
    - template: jinja
    - user: postgres
    - group: postgres
    - require:
      - pkg: postgresql_packages

{% set sysctl = '/etc/sysctl.d/30-postgresql.conf' %}
{% set mem = 8192 if 8192 < (grains['mem_total'] / 4) else (grains['mem_total'] / 4) %}
{% set shmmax = (1024**2 * mem * 1.1)|int %}
kernel.shmmax:
  sysctl.present:
    - config: {{ sysctl }}
    - value: {{ shmmax }}

# shmall = ceil(shmmax / pagesize)
{% shmall =  1 + (shmmax / 4096)|int %}
kernel.shmall:
  sysctl.present:
    - config: {{ systcl }}
    - value: {{ shmall }}

postgresql:
  service.running:
    - require:
      - sysctl: kernel.shmmax
      - sysctl: kernel.shmall
      - pkg: postgresql_packages
    - watch:
      - file: {{ postgresql_conf }}
