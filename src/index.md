---
# Feel free to add content and custom Front Matter to this file.

layout: default
pagination:
    collection: posts
    per_page: 5
---

<ul id="list-posts">
  <% paginator.resources.each do |post| %>
    <li>
      <%= render Home::PostCard.new(url: post.relative_url, title: post.data.title, summary: post.data.description, date: post.data.date) %>
    </li>
  <% end %>
</ul>