require 'tmdb_fetcher'

describe "TmdbFetcher" do

  let(:fetcher) { build(:tmdb_fetcher) }
  let(:correct_id) { 40662 }
  let(:incorrect_id) { 1000000000000 }
  let(:credits) { fetcher.send(:get, "#{correct_id}/credits") }
  let(:movie_link) { "http://api.themoviedb.org/3/movie/#{correct_id}" }
  let(:credits_link) { "http://api.themoviedb.org/3/movie/#{correct_id}/credits" }
  let(:top_rated_link) { "http://api.themoviedb.org/3/movie/top_rated" }
  let(:movie_hash) { [
      { link: "http://www.imdb.com/title/tt1569923",
        name: "Batman: Under the Red Hood",
        year: 2010,
        country: "US",
        date: "2010-07-27",
        genre: ["Adventure", "Animation", "Action", "Science Fiction", "Mystery"],
        duration: 75,
        rating: 7.5,
        director: "Brandon Vietti",
        actors: ["Bruce Greenwood", "Jensen Ackles", "Neil Patrick Harris", "Jason Isaacs", "John DiMaggio"]
      }
    ]
  }

  def make_movie
    Net::HTTP.get(URI(movie_link))
  end

  def make_movie_credits
    Net::HTTP.get(URI(credits_link))
  end

  def make_top_rated
    Net::HTTP.get(URI(top_rated_link))
  end

  describe "API" do
    it "doesn't get incorrect API key" do
      TmdbFetcher.key = "blabla"
      get "#{movie_link}?api_key=#{TmdbFetcher.key}"
      expect_status 401
    end
    it "gets correct API key" do
      TmdbFetcher.key = "dd165b18174b238eb2af5a0c3552f2f3"
      get "#{movie_link}?api_key=#{TmdbFetcher.key}"
      expect_status 200
    end
  end

  describe ".top_movie_ids" do

    let(:top_movie_ids) { fetcher.send(:top_movie_ids) }

    before :each do
      TmdbFetcher.movie_count 20
      make_top_rated
    end

    it "returns an array", vcr: true do
      expect(top_movie_ids).to be_a(Array)
    end

    it "returns not empty array", vcr: true do
      expect(top_movie_ids).not_to be_empty
    end

    it "returns not nil", vcr: true do
      expect(top_movie_ids).not_to be_nil
    end

    it "returns not nil values", vcr: true do
      expect(top_movie_ids.include?(nil)).to be_falsey
    end

  end

  describe ".parse" do

    before :each do
      make_movie
      make_movie_credits
    end

    it "returns an array", vcr: true do
      expect(fetcher.send(:parse, correct_id)).to be_a(Array)
    end

    it "returns not empty array", vcr: true do
      expect(fetcher.send(:parse, correct_id)).not_to be_empty
    end

    it "returns not nil", vcr: true do
      expect(fetcher.send(:parse, correct_id)).not_to be_nil
    end

    it "returns not nil values", vcr: true do
      expect(fetcher.send(:parse, correct_id).include?(nil)).to be_falsey
    end

    it "correctly parses information of the movie", vcr: true do
      expect(fetcher.send(:parse, correct_id)).to eq(movie_hash)
    end

  end

  describe ".get" do

    before :each do
      make_movie
      make_top_rated
    end

    it "parses JSON when passed only correct path", vcr: true do
      expect(fetcher.send(:get, correct_id)).to be_a(Hash)
    end

    it "parses JSON when passed path and page numer", vcr: true do
      expect(fetcher.send(:get, "top_rated", 1)).to be_a(Hash)
    end

    # it "throw an exception when path is incorrect", vcr: true do
    #   expect { fetcher.send(:get, "blabla") }.to raise_error("The passed path is incorrect, status code: 404")
    # end

  end

  describe ".get_director" do
    it "returns the director of the movie", vcr: true do
      make_movie_credits
      expect(fetcher.send(:get_director, credits)).to eq("Brandon Vietti")
    end
  end

  describe ".get_actors" do
    it "returns an array of the movie actors", vcr: true do
      make_movie_credits
      expect(fetcher.send(:get_actors, credits, 5)).to contain_exactly("Bruce Greenwood", "Jensen Ackles", "John DiMaggio", "Neil Patrick Harris", "Jason Isaacs")
    end
  end

  describe ".page_count" do
    it "returns page count", vcr: true do
      TmdbFetcher.movie_count 10
      make_top_rated
      expect(fetcher.send(:page_count)).to eq(1)
    end
  end

  describe ".get_imdb_link" do
    it "makes IMDB link" do
      imdb_id = "tt1569923"
      expect(fetcher.send(:get_imdb_link, imdb_id)).to eq("http://www.imdb.com/title/tt1569923")
    end
  end

end
