module Harvest
  module Resources
    # This class is a hack to maintain compatibility with the ActiveResource
    # API and Harvest's fucked time tracking API.
    class Timer < Harvest::HarvestResource
      self.element_name = 'daily'
      self.prefix = '/daily/:action_hack'
      self.collection_name = ''

      # Override to not use collection_path
      def create
        headers = self.class.headers.merge 'Accept' => 'application/xml'
        connection.post('/daily/add', encode, headers).tap do |response|
          self.id = id_from_response(response)
          load_attributes_from_response(response)
        end
      end

      # Override to use POST instead of PUT, and update path
      def update
        headers = self.class.headers.merge 'Accept' => 'application/xml'
        connection.post(element_path(prefix_options.merge(:action_hack => :update)), encode, headers).tap do |response|
          load_attributes_from_response(response)
        end
      end

      # Override to use delete path
      def destroy
        connection.delete(element_path(:action_hack => :delete), self.class.headers)
      end

      # Override to pull day_entry element data into attributes
      def initialize attributes={}
        @attributes     = {}
        @prefix_options = {}
        load(attributes.has_key?('day_entry') ? attributes['day_entry'] : attributes)
      end

      # Override to support Harvest's custom XML format
      def encode options={}
        massaged_attributes = {
          :notes => attributes['notes'],
          :hours => attributes['hours'].to_s,
          :project_id => (project ? project.id : nil),
          :task_id => (task ? task.id : nil),
          :spent_at => attributes['spent_at'] || Date.today
        }
        self.class.format.encode(massaged_attributes, {:root => 'request'}.merge(options))
      end

      def project
        @project ||= find_project
      end

      def find_project
        case p = attributes['project']
        when Integer then Harvest::Resources::Project.find(p)
        else; Harvest::Resources::Project.find(:all).find{|pp|pp.name.strip == p.to_s.strip}
        end
      end

      def task
        @task ||= find_task
      end

      def find_task
        case t = attributes['task']
        when Integer then Harvest::Resources::Task.find(t)
        else; Harvest::Resources::Task.find(:all).find{|tt|tt.name.strip == t.to_s.strip}
        end
      end

      class << self
        # Override to remove file extension
        def element_path_with_extension_removal id, prefix_options = {}, query_options = nil
          element_path_without_extension_removal(id, prefix_options, query_options).sub(/\.#{format.extension}/, '')
        end
        alias_method_chain :element_path, :extension_removal

        # Override to use show path
        def find_single_with_action_hack scope, options
          options ||= {} and options[:params] ||= {}
          options[:params].merge!(:action_hack => :show)
          find_single_without_action_hack scope, options
        end
        alias_method_chain :find_single, :action_hack

        # Override to use delete path
        def delete_with_action_hack id, options={}
          delete_without_action_hack id, options.merge(:action_hack => :delete)
        end
        alias_method_chain :delete, :action_hack
      end
    end
  end
end
