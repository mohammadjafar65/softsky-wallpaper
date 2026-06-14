import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const badgeVariants = cva(
    "inline-flex w-fit items-center gap-1 rounded-md border px-2.5 py-1 text-xs font-medium transition-colors",
    {
        variants: {
            variant: {
                default: "border-transparent bg-primary text-primary-foreground",
                secondary: "border-transparent bg-secondary text-secondary-foreground",
                outline: "border-border text-foreground",
                success: "border-emerald-200 bg-emerald-50 text-emerald-700",
                warning: "border-amber-200 bg-amber-50 text-amber-800",
                danger: "border-rose-200 bg-rose-50 text-rose-700",
                info: "border-sky-200 bg-sky-50 text-sky-700",
                muted: "border-slate-200 bg-slate-100 text-slate-600",
            },
        },
        defaultVariants: {
            variant: "default",
        },
    }
)

function Badge({
    className,
    variant,
    ...props
}: React.ComponentProps<"span"> & VariantProps<typeof badgeVariants>) {
    return <span data-slot="badge" className={cn(badgeVariants({ variant, className }))} {...props} />
}

export { Badge }
