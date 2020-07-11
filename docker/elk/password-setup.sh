#!/bin/bash

sh -c "/password-setup.exp"

curl --user elastic:qE*7Pj43Or -H "Content-Type: application/json" -d '{"cluster": ["manage_index_templates", "monitor"], "indices": [{"names": [ "*","logstash-*" ], "privileges": ["write","create","delete","create_index"]}]}' -X POST http://localhost:9200/_xpack/security/role/logstash_writer
curl --user elastic:qE*7Pj43Or -H "Content-Type: application/json" -d '{"password" : "qE*7Pj43Or","roles" : [ "logstash_writer"],"full_name" : "Internal Logstash User"}' -X POST http://localhost:9200/_xpack/security/user/logstash_internal