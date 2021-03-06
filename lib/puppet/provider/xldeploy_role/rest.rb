require 'uri'
require 'puppet_x/xebialabs/xldeploy/xldeploy.rb'


Puppet::Type.type(:xldeploy_role).provide :rest do

  def create
    xldeploy.rest_put("security/role/#{resource[:id]}")
  end

  def destroy
    xldeploy.rest_delete "security/role/#{resource[:id]}"
  end

  def exists?
    response = xldeploy.rest_get "security/role"
    if to_hash(response).has_key?('string')

      return true if to_hash(response)['string'].include? resource[:id]
    end
    return false
  end

  def granted_permissions
    output = {}

    resource[:granted_permissions].each do | ci, perm |
      if perm.is_a? Array
        output[ci] = []
        perm.each {| pe |  output[ci] << pe if has_permission(ci, resource[:id], pe) == true }
      else
        output[ci] = perm if has_permission(ci, resource[:id], perm) == true
      end
   end
    return output
  end

  def granted_permissions=(value)
    value.each do |ci, perm|
      if perm.is_a? Array
        perm.each {|pe| set_permission(ci,resource[:id], pe) }
      else
         set_permission(ci,resource[:id], perm)
      end
    end
  end

  def users
    output = []
    resource[:users].each do | user |
     output << user if has_role(user, resource[:id])
    end
  end

  def users=(value)
    assign_role(value, resource[:id])
  end

  #private
 def has_role(user,role)
    response = xldeploy.rest_get("security/role/roles/#{user}")
    return true if response =~ /#{role}/
    return false
  end

 def assign_role(user,role)
    xldeploy.rest_put("security/role/#{role}/#{user}")
 end

  def has_permission(ci,role,permission)
    response = xldeploy.rest_get("security/permission/#{URI.escape(permission)}/#{role}/#{ci}")
    return true if response =~ /true/
    return false
  end

  def set_permission(ci,role,permission)
    xldeploy.rest_put("security/permission/#{URI.escape(permission)}/#{role}/#{ci}")
  end

  def to_hash(input)
    doc = REXML::Document.new input
    data_hash = {}
    string_array = []
    doc.elements.each("/*/*") do |prop|
      if prop.name == 'string'
        string_array << prop.text
      end
    end
    data_hash['string'] = string_array
    return data_hash
  end

  private
  def xldeploy
    Xldeploy.new(resource[:rest_url], resource[:ssl], resource[:verify_ssl])
  end
end
