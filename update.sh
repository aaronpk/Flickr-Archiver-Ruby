#!/bin/bash

cd /web/Flickr-Archiver
/usr/local/bin/rake flickr:update[caseorganic] --trace
/usr/local/bin/rake flickr:update[aaronparecki] --trace


