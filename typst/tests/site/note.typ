// A template of the site's own: notes, at notes/<slug>/, with a topic in their header, and the website theme's look
// with a stylesheet of their own.
#import "../../lib.typ": *
#let note = template("note", ..(website.look + (css: website.look.css + (path("note.css"),))),
  url: slug => "notes/" + slug + "/",
  fields: (topic: none),
  required: ("topic",),
  header: page => html.elem("h1", page.title + " · " + page.topic),
)
#show: note.with("tori", title: "Tori", topic: "geometry")
Tori are surfaces.
