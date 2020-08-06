require 'net/http'
require 'uri'
require 'json'
require 'uri'
require 'dotenv/load'

module Jekyll
    class MeetupMembersCounterTag < Liquid::Tag

        attr_accessor :technologies

        def authorization_string
            return "client_id=#{ENV['CLIENT_ID']}&client_secret=#{ENV['CLIENT_SECRET']}"
        end

        def countIssues(user)
            uri = URI.parse("https://api.github.com/search/issues?q=author:#{user}&#{authorization_string}")

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request["Accept"] = 'application/vnd.github.cloak-preview'

            response = http.request(request)

            issues = JSON.parse(response.body)

            issues["total_count"]
        end

        def countRepos(user)
            uri = URI.parse("https://api.github.com/users/#{user}/repos?#{authorization_string}&per_page=100")

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request["Accept"] = 'application/vnd.github.cloak-preview'

            response = http.request(request)

            repos = JSON.parse(response.body)

            repos.each do |repo|
                getTechnologies(user, repo["name"])
            end

            repos = repos.select do | repo |
                !repo["fork"]
            end
            

            return repos.size
        end

        def countCommits(user)
            now = Time.new
            date_one_year_ago = "#{(now.year - 1).to_s}-#{now.month.to_s.rjust(2, '0')}-#{now.day.to_s.rjust(2, '0')}"
            uri = URI.parse("https://api.github.com/search/commits?q=author:#{user} committer-date:>#{date_one_year_ago}&#{authorization_string}")

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request["Accept"] = 'application/vnd.github.cloak-preview'

            response = http.request(request)

            commits = JSON.parse(response.body)

            return commits["total_count"]
        end

        def countStarts(user)
            uri = URI.parse("https://api.github.com/search/repositories?q=user:#{user} stars:>0&#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            repos = JSON.parse(response.body)
            counter = 0

            repos["items"].each do |repo|
                counter += (repo["stargazers_count"].to_i)
            end
            return counter

        end

        def getTechnologies(user, repo)
            uri = URI.parse("https://api.github.com/repos/#{user}/#{repo}/languages?#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            languages = JSON.parse(response.body)

            languages.each do |language, lines|
                counter = @technologies[language] || 0
                @technologies[language] = (counter + 1 ) 
            end
        end

        def getUserData(user)
            uri = URI.parse("https://api.github.com/users/#{user}?#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            user = JSON.parse(response.body)

            return user
        end

        def getTopUsersData
            @top_users = []

            max_commits = 0
            max_stars = 0
            max_followers = 0
            max_public_repos = 0
            max_issues = 0
            per_page = 30

            (1..2).each do |i|
                uri = URI.parse("https://api.github.com/search/users?q=location:mexico&followers:>10&per_page=#{per_page}&page=#{i}&sort=followers&order=desc&#{authorization_string}")

                response = Net::HTTP.get_response(uri)
                users = JSON.parse(response.body)

                users["items"].each do |user|
                    data = getUserData(user["login"])

                    p data["name"]

                    commits = countCommits(user["login"])
                    stars = countStarts(user["login"])
                    followers = data["followers"]
                    repos = countRepos(user["login"])
                    issues = countIssues(user["login"])

                    max_commits = commits if commits > max_commits
                    max_stars = stars if stars > max_stars
                    max_followers = followers if followers > max_followers
                    max_public_repos = repos if repos > max_public_repos
                    max_issues = issues if issues > max_issues

                    @top_users << {
                        id: user["login"],
                        pic: data["avatar_url"],
                        name: data["name"],
                        email: data["email"],
                        company: data["company"],
                        followers: followers,
                        repos: repos,
                        url: data["html_url"],
                        commits: commits,
                        stars: stars,
                        issues: issues
                    }
                end

            end
            @top_users.each do |user|
                user[:score] = (
                    user[:commits] / max_commits.to_f +
                    user[:stars] / max_stars.to_f +
                    user[:followers] / max_followers.to_f +
                    user[:repos] / max_public_repos.to_f +
                    user[:issues] / max_issues.to_f
                ) / 5.0
            end

            languages = @technologies.sort_by {|k,v| v}.reverse.first(15).to_h
            sum = languages.values.reduce(:+).to_f

            languages.each do |language, value|
                languages[language] = (value/sum * 100).round(2)
            end

            return @top_users.sort_by {|obj| obj[:score]}.reverse, languages
        end

        def render(context)
            users, languages = getTopUsersData
            element = "<script> draw_languages_chart(" + languages.to_json + ") </script>\n"
            element += "<script> drawTable(" + users.to_json + ") </script>\n"
        end

        def initialize(tag_name, text, tokens)
            super
            @technologies = Hash.new
        end
    end
end

Liquid::Template.register_tag('top_users', Jekyll::MeetupMembersCounterTag)