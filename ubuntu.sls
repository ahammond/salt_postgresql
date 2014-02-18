{% set pg_pref = '/etc/apt/preferences.d/pgdg.pref' %}
{% set ppa = 'deb http://ppa.launchpad.net/pitti/postgresql/ubuntu precise main' %}

{{ ppa }}
  pkgrepo.managed:
    - dist: precise
    - file: /etc/apt/sources.list.d/postgresql.list
    - keyid: FB322597BBC86D52FEE950E299B656EA8683D8A2
    - keyserver: keyserver.ubuntu.com

{{ pg_pref }}:
  file.managed:
    - source: salt://postgresql/files{{ pg_pref }}
    - require:
      - pkgrepo: {{ ppa }}

update_apt:
  cmd.wait:
    - name: apt-get update
    - require:
      - pkgrepo: {{ ppa }}
      - file: {{ pg_perf }}
    - watch:
      - file: /etc/apt/sources.list.d/*

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
      - sysctl: kernel.shmmax
      - sysctl: kernel.shmall
