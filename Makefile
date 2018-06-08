# template of Makefile

test: ## print test message
	@echo 20180508 | ./zeller.sh
	@echo 2018/05/09 | ./zeller.sh
	@echo 2018-05-11 | ./zeller.sh

.PHONY: help

help: ## print about the targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'
#.DEFAULT_GOAL := help
# https://postd.cc/auto-documented-makefile/
# https://www.gnu.org/software/make/manual/make.html#Standard-Targets

#https://kanasys.com/tech/522
##!/bin/bash
#make -j -f <(tail -n+$(expr $LINENO + 1) $0) $@ ;exit 0

