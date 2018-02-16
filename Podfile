# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'BrowserCore' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for BrowserCore
  pod 'RealmSwift'
  pod 'SnapKit', '~> 4.0.0'
  
  react_path = './JSEngine/node_modules/react-native'
  yoga_path = File.join(react_path, 'ReactCommon/yoga')
  
  pod 'React', :path => './JSEngine/node_modules/react-native', :subspecs => [
  'Core',
  'RCTText',
  'RCTNetwork',
  'RCTWebSocket',
  # needed for debugging
  # Add any other subspecs you want to use in your project
  ]
  pod 'Yoga', :path => yoga_path
  pod 'RNFS', :path => './JSEngine/node_modules/react-native-fs'

end
