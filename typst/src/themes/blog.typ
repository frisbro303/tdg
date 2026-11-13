// The blog theme: the website theme's look and templates (`standalone`, `home`), and `post`. Give the site a home
// page listing the posts, `#listing("post")`.

#import "../site.typ": template, to-date, pdf-title
#import "../layout.typ": post-header
#import "website.typ": look, standalone, home

#let _dated(page) = page + (date: to-date(page.date), updated: if page.updated != none { to-date(page.updated) })

/// A post: dated, at posts/<slug>/, with a PDF. Its settings: `date` ("YYYY-MM-DD" or a datetime) and `updated`,
/// shown beside it. List them with `#listing("post")`, and give them a feed with the site's `feed: "post"`. Use as
/// `#show: blog.post.with("hopf-fibrations", title: "...", date: "2026-11-03")`.
#let post = template("post", ..look,
  url: slug => "posts/" + slug + "/",
  fields: (date: none, updated: none),
  required: ("date",),
  prepare: _dated,
  header: post-header,
  pdf-header: pdf-title,
  pdf: true,
)
