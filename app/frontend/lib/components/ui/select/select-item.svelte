<script>
  import { cn } from "$lib/utils.js";

  export let value;
  export let className = "";
</script>

<div
  class={cn(
    "relative flex w-full cursor-default select-none items-center rounded-sm py-1.5 pl-2 pr-8 text-sm outline-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
    className,
  )}
  data-value={value}
  {...$$restProps}
>
  <slot />
</div>
