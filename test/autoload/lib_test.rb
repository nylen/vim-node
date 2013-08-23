require_relative "../helper"
require "json"

describe "Lib" do
  include WithTemporaryDirectory

  before do
    FileUtils.touch File.join(@dir, "package.json")
  end

  describe "node#lib#find" do
    def find(path)
      File.realpath($vim.echo(%(node#lib#find("#{path}", expand("%")))))
    end

    it "must return ./README before ./README.js" do
      touch File.join(@dir, "README")
      touch File.join(@dir, "README.js")

      $vim.edit File.join(@dir, "index.js")
      find("./README").must_equal File.join(@dir, "README")
    end

    it "must return ./README.txt relative to file" do
      touch File.join(@dir, "lib", "README.txt")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("./README.txt").must_equal File.join(@dir, "lib", "README.txt")
    end

    it "must return ../README.txt" do
      touch File.join(@dir, "README.txt")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("../README.txt").must_equal File.join(@dir, "README.txt")
    end

    it "must return /.../README.txt" do
      touch File.join(@dir, "README.txt")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/README.txt").must_equal File.join(@dir, "README.txt")
    end

    it "must return ./other.js given ./other" do
      touch File.join(@dir, "other.js")
      $vim.edit File.join(@dir, "index.js")
      find("./other").must_equal File.join(@dir, "other.js")
    end

    it "must return ./other.js given ./other relative to file" do
      touch File.join(@dir, "lib", "other.js")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("./other").must_equal File.join(@dir, "lib", "other.js")
    end

    it "must return ./other.js before ./other/index.js given ./other" do
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")
      $vim.edit File.join(@dir, "index.js")
      find("./other").must_equal File.join(@dir, "other.js")
    end

    it "must return ../other.js given ../other" do
      touch File.join(@dir, "other.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("../other").must_equal File.join(@dir, "other.js")
    end

    it "must return /.../other.js given /.../other" do
      touch File.join(@dir, "other.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/other").must_equal File.join(@dir, "other.js")
    end

    it "must return ./package.json given ./package" do
      touch File.join(@dir, "package.json")
      $vim.edit File.join(@dir, "index.js")
      find("./package").must_equal File.join(@dir, "package.json")
    end

    it "must return ./index.js given ." do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "other.js")
      find(".").must_equal File.join(@dir, "index.js")
    end

    it "must return ./index.js given ./" do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "other.js")
      find("./").must_equal File.join(@dir, "index.js")
    end

    it "must not find ./index/index.js given ./" do
      touch File.join(@dir, "index", "index.js")
      $vim.edit File.join(@dir, "other.js")
      $vim.echo(%(empty(node#lib#find("./", expand("%"))))).must_equal "1"
    end

    it "must not find ./.js given ./" do
      touch File.join(@dir, ".js")
      $vim.edit File.join(@dir, "other.js")
      $vim.echo(%(empty(node#lib#find("./", expand("%"))))).must_equal "1"
    end

    it "must return ../index.js given .." do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "other.js")
      find("..").must_equal File.join(@dir, "index.js")
    end

    it "must return ../index.js given ../" do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "other.js")
      find("../").must_equal File.join(@dir, "index.js")
    end

    it "must return /.../index.js given /..." do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir").must_equal File.join(@dir, "index.js")
    end

    it "must return /.../index.js given /.../" do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/").must_equal File.join(@dir, "index.js")
    end

    it "must return ./lib/index.js given ./lib" do
      touch File.join(@dir, "lib", "index.js")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./lib/other.js given ./lib with main" do
      touch File.join(@dir, "lib", "other.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "other")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "other.js")
    end

    it "must return ./lib/index.js given ./lib with empty main" do
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./lib/index.js given ./lib with non-existent main" do
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "new")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./other.js before ./other/index.js given . with main" do
      touch File.join(@dir, "package.json"), JSON.dump(:main => "other")
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")

      $vim.edit File.join(@dir, "index.js")
      find(".").must_equal File.join(@dir, "other.js")
    end

    it "must return node_modules/foo/index.js given foo" do
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index
      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal index
    end

    it "must return node_modules/foo/other.js given foo/other" do
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other
      $vim.edit File.join(@dir, "index.js")
      find("foo/other").must_equal other
    end

    it "must return node_modules/foo/other.js given foo/other.js" do
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other
      $vim.edit File.join(@dir, "index.js")
      find("foo/other.js").must_equal other
    end

    # When package.json refers to a regular file.
    it "must return node_modules/foo/other.js given foo with main" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./other.js")
      touch File.join(mod, "other.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "other.js")
    end

    # When package.json refers to a directory.
    it "must return node_modules/foo/lib/index.js given foo with main as ./lib" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "lib/index.js")
    end

    it "must return node_modules/foo/lib/index.js given foo with main as lib" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "lib/index.js")
    end

    it "must return empty when looking for nothing" do
      $vim.edit File.join(@dir, "index.js")
      $vim.echo(%(empty(node#lib#find("", expand("%"))))).must_equal "1"
    end

    it "must return empty when nothing found" do
      $vim.edit File.join(@dir, "index.js")
      $vim.echo(%(empty(node#lib#find("new", expand("%"))))).must_equal "1"
    end
  end

  describe "node#lib#glob" do
    require "json"

    before do
      $vim.edit File.join(@dir, "index.js")
    end

    def glob(arg = "")
      JSON.parse $vim.echo(%(node#lib#glob("#{arg}"))).gsub("'", '"')
    end

    it "must return all modules" do
      FileUtils.mkpath File.join(@dir, "node_modules", "require-guard")
      FileUtils.mkpath File.join(@dir, "node_modules", "export")
      FileUtils.mkpath File.join(@dir, "node_modules", "soul")
      glob.must_equal %w[export/ require-guard/ soul/]
    end

    it "must return all files and directories in module's directory" do
      touch File.join(@dir, "node_modules", "soul", "index.js")
      touch File.join(@dir, "node_modules", "soul", "README")
      FileUtils.mkpath File.join(@dir, "node_modules", "soul", "test")
      glob("soul").must_equal %w[soul/index.js soul/README soul/test/]
    end

    it "must not return files in module's subdirectories" do
      touch File.join(@dir, "node_modules", "soul", "index.js")
      touch File.join(@dir, "node_modules", "soul", "README")
      touch File.join(@dir, "node_modules", "soul", "test", "test.js")
      glob("soul").must_equal %w[soul/index.js soul/README soul/test/]
    end

    it "must return files with a single slash given one" do
      touch File.join(@dir, "node_modules", "soul", "index.js")
      FileUtils.mkpath File.join(@dir, "node_modules", "soul", "test")
      glob("soul/").must_equal %w[soul/index.js soul/test/]
    end

    it "must return files with two slashes given two" do
      touch File.join(@dir, "node_modules", "soul", "index.js")
      FileUtils.mkpath File.join(@dir, "node_modules", "soul", "test")
      glob("soul//").must_equal %w[soul//index.js soul//test/]
    end

    it "must return files with three slashes given three" do
      touch File.join(@dir, "node_modules", "soul", "index.js")
      FileUtils.mkpath File.join(@dir, "node_modules", "soul", "test")
      glob("soul///").must_equal %w[soul///index.js soul///test/]
    end
  end
end
