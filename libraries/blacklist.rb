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

class Blacklist
  # The filter function takes two arguments - the data you want to filter and a
  # blacklist map of the keys you want removed.  It is called recursively for
  # each level of data that is to be filtered.
  #
  #  * Key has either a Boolean value or a Hash as content
  #    * Key == "xxx"
  #      * The key is a string pattern to match on, as per knife search
  #      * Wildcards are:
  #        * '*' for 0 or more characters
  #        * '?' for a single character
  #    * Boolean == true
  #      * Prune entire subtree *INCLUSIVE* of this key
  #    * Boolean == false
  #      * Prune entire subtree *EXCLUSIVE* of this key
  #    * Hash == {}
  #      * Descend to next level and don't prune this key
  #
  # Blacklist.filter(
  # {
  #   "network" => {
  #     "interfaces" => {
  #       "tapf7db623c-1b" => {},
  #       "nldev.618" => {},
  #       "tapf7db623c-1c" => {},
  #       "tapf7db623c-1a" => {},
  #       "nldev.617" => {"addresses" => "all"},
  #       "nldev.619" => { "a" => "b" }
  #     }
  #   }
  # }
  # ,
  # {
  #   "network" => {
  #     "interfaces" => {
  #       "tap*" => true,
  #       "*" => {
  #         "addresses" => false,
  #         "mtu" => false,
  #         "*" => true
  #       }
  #     }
  #   }
  # }
  #)
  #
  # Will return:
  # {
  #   "network" => {
  #     "interfaces" => {
  #       "nldev.618" => {},
  #       "nldev.617" => {"addresses" => ""},
  #       "nldev.619" => {}
  #     }
  #   }
  # }
  #
  def self.filter(data, blacklist)
    # If data is nil there can't be anything to filter
    if data.nil?
      return nil
    end

    new_blacklist = {}
    # Anchor the match key to make as safe as possible,
    # and convert from knife search to ruby regexp syntax
    blacklist.each { |key, value|
      new_blacklist["^" + key.gsub(/\*/, ".*").gsub(/\?/, ".") + "$"] = value
    }
    blacklist = new_blacklist

    # Based on the stated rules, return true in the block for keys to delete from data
    data.delete_if { |k, v|
      # If the select on the blacklist hash returns an empty hash there are no keys
      matches = blacklist.select { |bk, bv|
        !k.match(bk).nil?
      }
      # Empty hash means no matching keys in the blacklist, so don't delete
      next false if matches.empty?

      # Find the most specific match if more than one match was made
      # Currently this simply uses the key of the longest length in the blacklist hash
      key_length = 0
      match = matches.select { |mk, mv|
        if mk.length > key_length
          key_length = mk.length
          next true
        end
        false
      }.flatten

      # match is now an array of [ key, value ] and value tells us what to do
      if match[1].kind_of?(Hash)
        # The blacklist value was a hash - descend!
        data[k] = filter(data[k], match[1])
        next false
      else
        # We are looking for true or false, true is easy, delete if the value is true
        next true if !!match[1]
        # Not true, so must be false
        # Set to a new object of the appropriate type (preserve type but drop contents)
        data[k] = data[k].class.new
        next false
      end
    }
  end
end

class Chef
  class Node
    alias_method :pre_blacklist_save, :save

    def save
      Chef::Log.info("Blacklisting node attributes")
      blacklist = self["blacklist"].to_hash

      # Make a copy of the current node state
      saved_default_attrs = self.default_attrs
      saved_normal_attrs = self.normal_attrs
      saved_override_attrs = self.override_attrs
      saved_automatic_attrs = self.automatic_attrs

      # Filter and save the node object
      self.default_attrs = Blacklist.filter(self.default_attrs, blacklist)
      self.normal_attrs = Blacklist.filter(self.normal_attrs, blacklist)
      self.override_attrs = Blacklist.filter(self.override_attrs, blacklist)
      self.automatic_attrs = Blacklist.filter(self.automatic_attrs, blacklist)
      pre_blacklist_save

      # Reset the node attributes for use, in case we were called during the chef run
      self.default_attrs = saved_default_attrs
      self.normal_attrs = saved_normal_attrs
      self.override_attrs = saved_override_attrs
      self.automatic_attrs = saved_automatic_attrs
    end
  end
end

