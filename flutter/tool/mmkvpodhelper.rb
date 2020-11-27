# to avoid conflict of the native lib name 'libMMKV.so' on iOS, we need to change the plugin name 'mmkv' to 'mmkvflutter'
def fix_mmkv_plugin_name_inside_dependencies(plugin_deps_file)
  plugin_deps_file = File.expand_path(plugin_deps_file)
  unless File.exists?(plugin_deps_file)
    raise "#{plugin_deps_file} must exist. If you're running pod install manually, make sure flutter pub get is executed first.(mmkvpodhelper.rb)"
  end

  plugin_deps = JSON.parse(File.read(plugin_deps_file))
  (plugin_deps.dig('plugins', 'ios') || []).each do |plugin|
    if plugin['name'] == 'mmkv'
      plugin['name'] = 'mmkvflutter'

      json = plugin_deps.to_json
      File.write(plugin_deps_file, json)
      return
    end
  end
end

# to avoid conflict of the native lib name 'libMMKV.so' on iOS, we need to change the plugin name 'mmkv' to 'mmkvflutter'
def fix_mmkv_plugin_name_inside_registrant(plugin_registrant_path, is_module)
  if is_module
    plugin_registrant_file = File.expand_path(File.join(plugin_registrant_path, 'FlutterPluginRegistrant.podspec'))
    if File.exists?(plugin_registrant_file)
      registrant = File.read(plugin_registrant_file)
      if registrant.sub!("dependency 'mmkv'", "dependency 'mmkvflutter'")
        File.write(plugin_registrant_file, registrant)
      end
    end
  end

  plugin_registrant_source = is_module ? File.expand_path(File.join(plugin_registrant_path, 'Classes', 'GeneratedPluginRegistrant.m'))
    : File.expand_path(File.join(plugin_registrant_path, 'GeneratedPluginRegistrant.m'))
  if File.exists?(plugin_registrant_source)
    registrant_source = File.read(plugin_registrant_source)
    if registrant_source.gsub!(/\bmmkv\b/, 'mmkvflutter')
      File.write(plugin_registrant_source, registrant_source)
    end
  end
end

def mmkv_fix_plugin_name(flutter_application_path, is_module)
  if is_module
    flutter_dependencies_path = File.join(flutter_application_path, '.flutter-plugins-dependencies')
    fix_mmkv_plugin_name_inside_dependencies(flutter_dependencies_path)

    flutter_registrant_path = File.join(flutter_application_path, '.ios', 'Flutter', 'FlutterPluginRegistrant')
    fix_mmkv_plugin_name_inside_registrant(flutter_registrant_path, is_module)
  else
    flutter_dependencies_path = File.join(flutter_application_path, '..', '.flutter-plugins-dependencies')
    fix_mmkv_plugin_name_inside_dependencies(flutter_dependencies_path)

    flutter_registrant_path = File.join(flutter_application_path, 'Runner')
    fix_mmkv_plugin_name_inside_registrant(flutter_registrant_path, is_module)
  end
end

def load_mmkv_plugin_deps(flutter_application_path)
  func, flutter_dependencies_path, is_module = (defined? flutter_parse_plugins_file) ? 
    [method(:flutter_parse_plugins_file), File.join(flutter_application_path, '..', '.flutter-plugins-dependencies'), false]
  : (defined? flutter_parse_dependencies_file_for_ios_plugin) ? 
    [method(:flutter_parse_dependencies_file_for_ios_plugin), File.join(flutter_application_path, '.flutter-plugins-dependencies'), true]
  : [nil, nil, false]
  unless func
    raise "must load/require flutter's podhelper.rb before calling #{__method__}"
  end
  plugin_deps = func.call(flutter_dependencies_path)
  return plugin_deps
end