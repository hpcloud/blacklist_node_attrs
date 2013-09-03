#
# Author:: Jon-Paul Sullivan
# Copyright:: Copyright (c) 2013 Hewlett-Packard Development Company, L.P.
# License:: Apache License, Version 2.0
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

require File.expand_path('./spec_helper.rb', File.dirname(__FILE__))

describe Blacklist do
  describe '.filter' do
    # Set the attributes that we are going to blacklist
    #node_attrs['network'] ||= {}
    #node_attrs['network']['interfaces'] ||= {}
    #node_attrs['network']['interfaces']['tapf7db623c-1b'] ||= {}
    #node_attrs['network']['interfaces']['nldev.618'] ||= {}
    #node_attrs['network']['interfaces']['tapf7db623c-1c'] ||= {}
    #node_attrs['network']['interfaces']['tapf7db623c-1a'] ||= {}
    #node_attrs['network']['interfaces']['nldev.617'] ||= { "addresses" => "all" }
    #node_attrs['network']['interfaces']['nldev.619'] ||= { "a" => "b" }
    let(:node_attrs) do
     {
       "network" => {
         "interfaces" => {
           "tapf7db623c-1b" => {},
           "nldev.618" => {},
           "tapf7db623c-1c" => {},
           "tapf7db623c-1a" => {},
           "nldev.617" => {"addresses" => "all"},
           "nldev.619" => { "a" => "b" }
         }
       }
     }
    end
    #blacklist['network'] ||= {}
    #blacklist['network']['interfaces'] ||= {}
    #blacklist['network']['interfaces']['tap*'] ||= true
    #blacklist['network']['interfaces']['*'] ||= {}
    #blacklist['network']['interfaces']['*']['addresses'] ||= false
    #blacklist['network']['interfaces']['*']['mtu'] ||= false
    #blacklist['network']['interfaces']['*']['*'] ||= true
    let(:blacklist) do
      {
        "network" => {
          "interfaces" => {
            "tap*" => true,
            "*" => {
              "addresses" => false,
              "mtu" => false,
              "*" => true
            }
          }
        }
      }
    end
    # Set the expected output
    #output['network'] ||= {}
    #output['network']['interfaces'] ||= {}
    #output['network']['interfaces']['nldev.618'] ||= {}
    #output['network']['interfaces']['nldev.617'] ||= { "addresses" => "" }
    #output['network']['interfaces']['nldev.619'] ||= {}
    let(:output) do
      {
        "network" => {
          "interfaces" => {
            "nldev.618" => {},
            "nldev.617" => {"addresses" => ""},
            "nldev.619" => {}
          }
        }
      }
    end

    it 'blacklists correctly' do
        Blacklist.filter(node_attrs, blacklist).should eq(output)
    end
  end
end
