module Princely
  module AssetSupport
    def localize_html_string(html_string, asset_path = nil)
      html_string = html_string.to_str
      # Make all paths relative, on disk paths...
      html_string.gsub!(".com:/",".com/") # strip out bad attachment_fu URLs
      html_string.gsub!( /src=["']+([^:]+?)["']/i ) do |m|
        src_path = $1
        if src_path =~ /^\/\//
          asset_src = src_path.gsub(/^\/\//, 'http://')
        else
          asset_src = asset_path ? "#{asset_path}/#{src_path}" : asset_file_path(src_path)
        end

        %Q{src="#{asset_src}"} # re-route absolute paths
      end

      # Remove asset ids on images with a regex
      html_string.gsub!( /src=["'](\S+\?\d*)["']/i ) { |m| %Q{src="#{$1.split('?').first}"} }
      html_string
    end

    def asset_file_path(asset)
      filename = asset.gsub(%r{/assets/}, "")

      if Rails.application.assets
        Rails.application.assets.find_asset(filename)&.filename
      elsif Rails.application.assets_manifest
        begin
          Rails.public_path.join('assets', Rails.application.assets_manifest.assets[filename])
        rescue TypeError
          nil
        end
      end || asset
    end
    alias_method :stylesheet_file_path, :asset_file_path
  end
end
