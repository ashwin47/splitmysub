<script>
  import { cn } from "$lib/utils.js";
  import { ChevronDown } from "@lucide/svelte";

  export let className = "";
</script>

<button
  type="button"
  class={cn(
    "flex h-9 w-full items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 [&>span]:line-clamp-1",
    className,
  )}
  {...$$restProps}
>
  <slot />
  <ChevronDown class="h-4 w-4 opacity-50" />
</button>
