import type { Metadata } from "next";
import { NewFrameApp } from "./new-frame-app";

export const metadata: Metadata = {
  title: "Command Center",
  description: "FRAME OS internal business operations command center.",
};

export default function Home() {
  return <NewFrameApp />;
}
