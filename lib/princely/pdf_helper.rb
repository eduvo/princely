require 'princely'
require 'princely/asset_support'

module Princely
  module PdfHelper
    def self.included(base)
      base.send :alias_method, :render_without_princely, :render
      base.send :alias_method, :render, :render_with_princely
    end

    def self.prepended(base)
      base.send :alias_method, :render_without_princely, :render
      base.send :alias_method, :render, :render_with_princely
    end

    def render_with_princely(options = nil, *args, &block)
      if options.is_a?(Hash) && options.has_key?(:pdf)
        options[:name] ||= options.delete(:pdf)
        make_and_send_pdf(options.delete(:name), options)
      else
        render_without_princely(options, *args, &block)
      end
    end

    private

    def make_pdf(options = {})
      options = {
        :stylesheets => [],
        :layout => false,
        :template => File.join(controller_path, action_name),
        :relative_paths => true,
        :server_flag => false,
        :media => nil,
        :javascript_flag => false
      }.merge(options)

      prince = Princely::Pdf.new(options.slice(:server_flag, :javascript_flag, :media))
      # Sets style sheets on PDF renderer
      prince.add_style_sheets(*options[:stylesheets].map { |style| asset_file_path(File.extname(style).blank? ? "#{style}.css" : style) })

      html_string = render_to_string(options.slice(:template, :layout, :handlers, :formats, :locals))

      html_string = localize_html_string(html_string, Rails.public_path) if options[:relative_paths]

      # Send the generated PDF file from our html string.
      if filename = options[:filename] || options[:file]
        prince.pdf_from_string_to_file(html_string, filename)
      else
        prince.pdf_from_string(html_string)
      end
    end

    def make_and_send_pdf(pdf_name, options = {})
      options = {:disposition => 'attachment'}.merge(options)
      send_data(
        make_pdf(options),
        :filename => "#{pdf_name}.pdf",
        :type => 'application/pdf',
        :disposition => options[:disposition]
      )
    end
  end
end
