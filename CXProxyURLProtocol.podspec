

Pod::Spec.new do |s|

s.name         = "CXProxyURLProtocol"
s.version      = "0.0.1"
s.summary      = "CXProxyURLProtocol"

s.description  = <<-DESC
Use custom NSURLProtocol to cache UIWebview.
DESC

s.homepage     = "https://github.com/CXTretar/CXProxyURLProtocol"
s.license      = "MIT"

s.author       = { "CXTretar" => "misscxuan@163.com" }

s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/CXTretar/CXProxyURLProtocol.git", :tag => s.version.to_s }

s.source_files  = "CXProxyURLProtocol/CXProxyURLProtocol/*.{h,m}"

s.requires_arc = true

end
