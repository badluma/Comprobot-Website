import index from "./index.html";

Bun.serve({
  routes: {
    "/": index,
    "/install.sh": () =>
      new Response(Bun.file("./install.sh"), {
        headers: { "Content-Type": "text/x-shellscript; charset=utf-8" },
      }),
    "/install.ps1": () =>
      new Response(Bun.file("./install.ps1"), {
        headers: { "Content-Type": "text/plain; charset=utf-8" },
      }),
  },
  development: {
    hmr: true,
    console: true,
  },
});
