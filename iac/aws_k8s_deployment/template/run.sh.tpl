#!/bin/bash

while true; do cd /opt/ftl/msa && poetry run python ftl_msa_rmq_out/msa/run.py; sleep 60; done
