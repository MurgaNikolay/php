#
# Author::  Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: php
# Recipe:: package
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

configure_options = node['php']['configure_options'].join(' ')

include_recipe 'build-essential'
include_recipe 'xml'
include_recipe 'yum-epel' if node['platform_family'] == 'rhel'

pkgs = value_for_platform_family(
  %w{ rhel fedora } => %w{ bzip2-devel libc-client-devel curl-devel freetype-devel gmp-devel libjpeg-devel krb5-devel libmcrypt-devel libpng-devel openssl-devel t1lib-devel mhash-devel },
  %w{ debian ubuntu } => %w{ libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev },
  'default' => %w{ libbz2-dev libc-client2007e-dev libcurl4-gnutls-dev libfreetype6-dev libgmp3-dev libjpeg62-dev libkrb5-dev libmcrypt-dev libpng12-dev libssl-dev libt1-dev }
  )

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

version = node['php']['version']

remote_file "#{Chef::Config[:file_cache_path]}/php-#{version}.tar.gz" do
  source "#{node['php']['url']}/php-#{version}.tar.gz/from/this/mirror"
  checksum node['php']['checksum']
  mode '0644'
  not_if "which #{node['php']['bin']}"
end

if node['php']['ext_dir']
  directory node['php']['ext_dir'] do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
  end
  ext_dir_prefix = "EXTENSION_DIR=#{node['php']['ext_dir']}"
else
  ext_dir_prefix = ''
end

bash 'build php' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
  tar -zxf php-#{version}.tar.gz
  (cd php-#{version} && #{ext_dir_prefix} ./configure #{configure_options})
  (cd php-#{version} && make && make install)
  EOF
  not_if "which #{node['php']['bin']}"
end

directory node['php']['conf_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

directory node['php']['ext_conf_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

include_recipe "php::ini"
