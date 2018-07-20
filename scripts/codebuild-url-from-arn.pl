#!/usr/bin/env perl

# create the codebuild page url from the ARN (which _is_ provided in the environment)
# used to link to the build from github status
# an alternative would be to get to the logs. However, the logs are linked from the dashboard, while the dashboard is not linked from the logs

# @afirth 2018-06

use strict; use warnings;

my $arn = $ENV{'CODEBUILD_BUILD_ARN'};

$arn =~ m|arn:aws:codebuild:(?<region>[^:]+):(?<account>[^:]+):build/(?<build>.*)|;

my @parts = (
  "https://console.aws.amazon.com/codebuild/home?region=",
  $+{region},
  "#/builds/",
  $+{build},
  "/view/new"
);

print join( "", @parts );
