{% for user, arguments in pillar['postgresql']['users']|dictsort %}
postgres_user_{{ user }}:
  postgres_user.present:
    - name: {{ user }}
    - runas: postgres
    {% for k, v in arguments|dictsort %}
    - {{ k }}: {{ v }}
    {% endfor %}
{% endfor %}
