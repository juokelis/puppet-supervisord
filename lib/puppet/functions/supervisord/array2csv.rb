# @summary
#   Returns a sorted csv formatted string from an array in the form
#   VALUE1,VALUE2,VALUE3
#
# Converts the array to a csv string
#
# $array = [ 'string1', 'string2', 'string3' ]
#
# becomes:
#
# $string = "string1,string2,string3"
Puppet::Functions.create_function(:'supervisord::array2csv') do
  # @param array
  #   The input array.
  #
  # @return [String]
  #   Returns a sorted csv formatted string.
  dispatch :supervisord_array2csv do
    required_param 'Array', :array
    return_type 'String'
  end

  def supervisord_array2csv(array)
    sorted_array = array.sort
    result = ''

    sorted_array.each {|value|
      result += "#{value},"
    }

    return result.chop!
  end
end
