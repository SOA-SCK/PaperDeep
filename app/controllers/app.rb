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
        origins '*'
        resource '*', headers: :any, methods: allowed_methods
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
        # Get cookie viewer's previously seen projects
        puts session[:paper]
        session[:paper] = "iot" if session[:paper].nil?
        session[:publication] ||= []

        puts "root: "
        puts session[:paper]
        
        # # Load previously viewed projects
        # publication =  Repository::For.entity(Entity::Publication).all.first.db_find_or_create(session[:publication])
        # # db_publication = PaperDeep::Repository::For.entity(publications_parse_result.first).all.first

        # puts publication
        # puts session[:publication]
        # session[:publication] = publication
        # puts session[:publication]

        # if projects.none?
        #   flash.now[:notice] = 'Add a Github project to get started'
        # end

        File.read('app/presentation/built/index.html')
      end

      routing.on ['test2', 'citedResult'] do
        File.read('app/presentation/built/index.html')
      end

      #########################################
      #   For Apis
      routing.on 'cookie' do
        routing.is do
          routing.get do
            # Load previously viewed projects
            # publication =  Repository::For.klass(Entity::Publication).db_find_or_create(session[:watching])
            # puts session[:watching]
            # session[:watching] = publication
            # puts session[:watching]
            # puts session[:qqq]
            # ppp = session

            puts "cookie: "
            puts session[:paper]
            puts session[:publication]
            # puts ppp
            # puts session
            # return qqq
          end
        end
      end
      routing.on 'search' do
        routing.is do
          # POST /search/
          routing.post do
            params = JSON.parse(routing.body.read)
            scopus = PaperDeep::PaperMapper.new(App.config.api_key)
            result = scopus.search(params['keyword'])[0] if session[:paper].nil?
            if result[:error] == 'Result set was empty'
              return { result: false, error: 'Having trouble searching' }.to_json; end

            scopus_parse_project = scopus.parse

            puts "search paper: "
            puts session[:paper]
            session[:paper] = "blockchain"
            puts session[:paper]

            begin
              # Add a result to database
              scopus_parse_project.map do |paper|
                Repository::For.entity(paper).db_find_or_create(paper)
              end
              
              papers_content = Views::PapersList.new(scopus_parse_project).content

              # puts "search paper: "
              # session[:paper] = "block"
              # puts session[:paper]
              # session[:paper].insert(0, "blockchain").uniq!

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
              rescue StandardError => err
                return { result: false, error: 'Having trouble searching publication' }.to_json
              end
              publications = scopus.parse

              
              begin
                # Add a result to database
                publications.map do |publication|
                  Repository::For.entity(publication).db_find_or_create(publication)
                end
                
                publications_content = Views::PapersList.new(publications).content

                # Add new keyword to watched set in cookies
                session[:publication].insert(0, "publication").uniq!
                puts "search publication"
                puts session[:publication]

                publications.map(&:content).to_json
              rescue StandardError
                flash[:error] = 'Having trouble accessing to database publication'
                return { result: false, error: flash[:error] }.to_json
              end

              
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
            # POST /db/
            routing.post do
              params = JSON.parse(routing.body.read)
              paper = Repository::For.klass(Entity::Paper).find_eid(params['eid'])
              return { result: false, error: 'Having trouble getting publication from database' }.to_json if paper.nil?

              paper.content.to_json
            end
          end
        end
      end

      #########################################
    end
  end
end
