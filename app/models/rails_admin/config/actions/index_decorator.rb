module RailsAdmin
  module Config
    module Actions
      Index.class_eval do

        register_instance_option :controller do
          proc do
            #Patch
            if params['save_filters']== 'true'
              model = abstract_model.model rescue nil
              if model
                data_type = nil
                dt_name = ''
                if (dt = model.data_type).is_a?(Setup::BuildInDataType)
                  dt_name = dt.name
                  namespace, name = dt.name.split('::')
                  data_type = Setup::CenitDataType.find_or_create_by(namespace: namespace, name: name)
                else
                  dt_name = dt.custom_title('/')
                  data_type = dt
                end
                # to suggest a unique default filter name, Example: 'Util/Logs_filter_1'
                prefix = "#{dt_name}_filter_"
                reg_exp = /^#{prefix}(\d+)/
                filter_name = (last_filter = Setup::Filter.where(:name => reg_exp).sort(:created_at => 1).last) ? "#{prefix}#{last_filter.name.match(reg_exp)[1].to_i + 1}" : "#{prefix}1"

                attr = {
                  "namespace": '',
                  "name": filter_name,
                  "triggers": params[:f].to_json,
                  "data_type_id": data_type
                }

                new_filter = Setup::Filter.create(attr)
                redirect_to rails_admin.edit_path(model_name: Setup::Filter.to_s.underscore.gsub('/', '~'), id: new_filter.id)
              else
                redirect_to back_or_index
              end
            else
              if current_user || model_config.public_access?
                begin
                  @objects ||= list_entries

                  unless @model_config.list.scopes.empty?
                    if params[:scope].blank?
                      unless @model_config.list.scopes.first.nil?
                        @objects = @objects.send(@model_config.list.scopes.first)
                      end
                    elsif @model_config.list.scopes.collect(&:to_s).include?(params[:scope])
                      @objects = @objects.send(params[:scope].to_sym)
                    end
                  end

                  respond_to do |format|
                    format.html do
                      render @action.template_name, status: (flash[:error].present? ? :not_found : 200)
                    end

                    format.json do
                      output = begin
                        if params[:compact]
                          primary_key_method = @association ? @association.associated_primary_key : @model_config.abstract_model.primary_key
                          label_method = @model_config.object_label_method
                          @objects.collect { |o| { id: o.send(primary_key_method).to_s, label: o.send(label_method).to_s } }
                        else
                          @objects.to_json(@schema)
                        end
                      end
                      if params[:send_data]
                        send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
                      else
                        render json: output, root: false
                      end
                    end

                    format.xml do
                      output = @objects.to_xml(@schema)
                      if params[:send_data]
                        send_data output, filename: "#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
                      else
                        render xml: output
                      end
                    end

                    format.csv do
                      header, encoding, output = CSVConverter.new(@objects, @schema).to_csv(params[:csv_options])
                      if params[:send_data]
                        send_data output,
                                  type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                                  disposition: "attachment; filename=#{params[:model_name]}_#{DateTime.now.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
                      else
                        render text: output
                      end
                    end
                  end
                rescue Exception => ex
                  flash[:error] = ex.message
                  redirect_to dashboard_path
                end
              else
                redirect_to new_session_path(User)
              end
            end
          end
        end
      end
    end
  end
end
