import { createFileRoute, Outlet } from "@tanstack/react-router";
import { MainLayout } from "@/components/layout/MainLayout";

// @ts-expect-error - TanStack Router file route has recursive type
export const Route = createFileRoute("/")({
  component: RootComponent,
});

function RootComponent() {
  return (
    <MainLayout>
      <Outlet />
    </MainLayout>
  );
}
