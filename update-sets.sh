#!/bin/bash

cd /web/Flickr-Archiver
/usr/local/bin/rake flickr:sets[caseorganic] --trace
/usr/local/bin/rake flickr:sets[aaronparecki] --trace


