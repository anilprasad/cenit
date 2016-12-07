module RailsAdmin
  module Config
    module Fields
      module Types
        class Code < RailsAdmin::Config::Fields::Types::CodeMirror

          register_instance_option :html_attributes do
            { cols: '74', rows: '15' }
          end

          register_instance_option :pretty_value do
            js_data = {
              csspath: css_location,
              jspath: js_location,
              options: config,
              locations: assets
            }.to_json.to_s

            pretty_value = <<-HTML
            <form id="code_show_view"><textarea data-richtext="codemirror" data-options=#{js_data}> #{value}
            </textarea></form>
            HTML

            pretty_value.html_safe
          end

          register_instance_option :js_location do
            bindings[:view].asset_path('codemirror.js')
          end

          register_instance_option :css_location do
            bindings[:view].asset_path('codemirror.css')
          end

          register_instance_option :assets do
            {
              mode: bindings[:view].asset_path("codemirror/modes/#{mode_file}.js"),
              theme: bindings[:view].asset_path("codemirror/themes/#{config[:theme]}.css")
            }
          end

          register_instance_option :config do
            default_config.merge(code_config)
          end

          register_instance_option :default_config do
            {
              lineNumbers: true,
              theme: (theme = User.current.try(:code_theme)).present? ? theme : (Cenit.default_code_theme || 'monokai')
            }
          end

          register_instance_option :code_config do
            {
            }
          end

          register_instance_option :mode_file do
            {
              'application/json': 'javascript',
              'application/ld+json': 'javascript',
              'application/x-ejs': 'htmlembedded',
              'application/x-erb': 'htmlembedded',
              'application/xml': 'xml',

              'text/apl': 'apl',
              'text/html': 'xml',
              'text/plain': 'javascript',
              'text/x-ruby': 'ruby',
              'text/x-yaml': 'yaml',
              '': 'javascript'
            }[config[:mode].to_s.to_sym] || config[:mode].to_sym
          end
        end
      end
    end
  end
end
