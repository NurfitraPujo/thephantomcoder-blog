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

  <% if paginator.total_pages > 1 %>
    <ul class="pagination">
      <% if paginator.previous_page %>
        <li>
          <a href="<%= paginator.previous_page_path %>">Previous Page</a>
        </li>
      <% end %>
      <% if paginator.next_page %>
        <li>
          <a href="<%= paginator.next_page_path %>">Next Page</a>
        </li>
      <% end %>
    </ul>
  <% end %>
</ul>