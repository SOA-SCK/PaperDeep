# frozen_string_literal: true

require 'roda'
require 'slim'
require 'rack/cors'
require 'json'

module PaperDeep
  # Web App
  class App < Roda
    use Rack::Cors, debug: true, logger: Logger.new($stdout) do
      allowed_methods = %i[get post put delete options head]
      allow do
        origins 'localhost:*'
        resource '*', headers: :any, methods: allowed_methods, credentials: true
      end
    end
    plugin :public, root: 'app/presentation/built', gzip: true
    plugin :halt
    plugin :flash
    route do |routing|
      #########################################
      #   For render react static files
      routing.public

      #   GET /
      routing.root do
        File.read('app/presentation/built/index.html')
      end

      routing.on ['test2', 'citedResult'] do
        File.read('app/presentation/built/index.html')
      end

      #########################################
      #   For Apis
      routing.on 'search' do
        routing.is do
          # POST /search/
          routing.post do
            params = JSON.parse(routing.body.read)
            scopus = PaperDeep::PaperMapper.new(App.config.api_key)
            result = scopus.search(params['keyword'])[0]

            if result[:error] == 'Result set was empty'
              return { result: false, error: 'Having trouble searching' }.to_json; end

            scopus_parse_project = scopus.parse

            begin
              # Add a result to database
              scopus_parse_project.map do |paper|
                Repository::For.entity(paper).db_find_or_create(paper)
              end
              papers_content = Views::Papers.new(scopus_parse_project).content.to_json

            rescue StandardError
              flash[:error] = 'Having trouble accessing to database paper'
              return { result: false, error: flash[:error] }.to_json
            end
          end
        end
        routing.on 'publication' do
          routing.is do
            # POST /search/publication
            routing.post do
              params = JSON.parse(routing.body.read)
              scopus = PaperDeep::PublicationMapper.new(App.config.api_key)
              begin
                result = scopus.search(params['pid'])
                return { result: false, error: 'Publication search result is nil' }.to_json if result.nil?
              rescue StandardError
                return { result: false, error: 'Having trouble searching publication' }.to_json
              end
              publications = scopus.parse

              begin
                # Add a result to database
                publications.map do |publication|
                  Repository::For.entity(publication).db_find_or_create(publication)
                end

                publications_content = Views::Publications.new(publications).content.to_json

              rescue StandardError
                flash[:error] = 'Having trouble accessing to database publication'
                return { result: false, error: flash[:error] }.to_json
              end
            end
          end
        end
        routing.on 'citationtree' do
          routing.is do
            # GET /search/citationtree
            routing.get do
              root_paper = session[:paper].first
              scopus = PaperDeep::PaperMapper.new(App.config.api_key)

              tree = PaperDeep::Services::CreateCitationTree.new(scopus, root_paper)
              tree.create
              tree_hash = tree.return_tree

              tree_json = tree_hash.to_json

            end
          end
        end
      end

      ######################################
      routing.on 'db' do
        routing.is do
          # GET /db/

          routing.get do
            paper = Repository::For.klass(Entity::Paper).all
            paper.map(&:content).to_json
          end
        rescue StandardError
          flash[:error] = 'Having trouble getting papers from database'
          return { result: false, error: flash[:error] }.to_json
        end
        routing.on 'eid' do
          routing.is do
            # POST /db/eid
            routing.post do
              session.clear
              session[:paper] ||= []
              params = JSON.parse(routing.body.read)

              paper = Repository::For.klass(Entity::Paper).find_eid(params['eid'])
              return { result: false, error: 'Having trouble getting publication from database' }.to_json if paper.nil?

              session[:paper].insert(0, paper.content)
              paper.content.to_json
            end
          end
        end
      end

      #########################################
    end
  end
end