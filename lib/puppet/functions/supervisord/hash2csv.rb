# @summary
#   Returns a csv formatted string from an hash in the form
#   KEY=VALUE,KEY2=VALUE2,KEY3=VALUE3 ordered by key
#
# Converts the hash to a csv string
#
# $hash = {
#   HOME   => '/home/user',
#   ENV1   => 'env1',
#   SECRET => 'secret'
# }
#
# becomes:
#
# $string = "HOME='/home/user',ENV1='env1',SECRET='secret'"
Puppet::Functions.create_function(:'supervisord::hash2csv') do
  # @param hash
  #   The input hash.
  #
  # @return [String]
  #   Returns a csv formatted string.
  dispatch :supervisord_hash2csv do
    required_param 'Hash', :hash
    return_type 'String'
  end

  def supervisord_hash2csv(hash)
    sorted_hash = hash.sort
    result = ''

    sorted_hash.each {|key, value|
      result += "#{key}='#{value}',"
    }

    return result.chop!
  end
end
