import React from "react";
import "@/App.css";
import {
  Lightning, Brain, ArrowRight, CaretRight, CaretDown,
  TreeStructure, CloudArrowUp, Terminal, Timer, Database,
} from "@phosphor-icons/react";

import { TreeView, MethodBadge, ModelCard } from "@/components/ScaffoldParts";
import {
  FILE_TREE, TECH_STACK, PIPELINE_STAGES, API_ROUTES,
  MODELS, ENV_VARS, ENUMS,
} from "@/data/scaffoldData";

const HERO_BG = "https://images.unsplash.com/photo-1683447551794-1c287cd42675?w=1200&q=30";

const TAGS = ["FastAPI","Flutter","Google ADK","Firestore","BigQuery","Cloud Run","Pub/Sub","APScheduler"];
const CICD_STEPS = ["Push to main triggers workflow","Auth via GCP_SA_KEY secret","Build Docker image","Push to Artifact Registry","Deploy to Cloud Run asia-south1"];

function App() {
  return (
    <div className="min-h-screen bg-white">
      <Header />
      <main className="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Hero />
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
          <FileTreePanel />
          <TechStackSection />
          <PipelineSection />
          <ApiRoutesSection />
          <ModelsSection />
          <SidebarInfo />
          <EnvVarsSection />
        </div>
        <Footer />
      </main>
    </div>
  );
}

function Header() {
  return (
    <header className="sticky top-0 z-50 bg-white/70 backdrop-blur-xl border-b border-slate-200 shadow-sm" data-testid="header-nav">
      <div className="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <TreeStructure size={22} weight="bold" className="text-[#002FA7]" />
          <h1 className="text-lg tracking-tight">
            <span className="font-light">Community</span><span className="font-black">Pulse</span>
            <span className="text-xs font-mono text-slate-400 ml-2">scaffold-preview</span>
          </h1>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-xs font-mono text-slate-500" data-testid="version-tag">v0.1.0</span>
          <span className="text-xs font-mono bg-[#002FA7] text-white px-3 py-1" data-testid="gsc-badge">GSC 2026</span>
        </div>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section className="relative border border-slate-200 p-8 mb-8 overflow-hidden" data-testid="architecture-hero">
      <div className="absolute inset-0 opacity-[0.04] bg-cover bg-center" style={{ backgroundImage: `url(${HERO_BG})` }} />
      <div className="relative z-10">
        <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-2">Architecture Overview</p>
        <h2 className="text-4xl sm:text-5xl tracking-tight leading-none font-light mb-4">
          Nova Rangers<span className="font-black text-[#002FA7]"> Scaffold</span>
        </h2>
        <p className="text-base leading-relaxed text-slate-600 max-w-3xl mb-6">
          Data-driven volunteer coordination for social-impact NGOs in Madhya Pradesh.
          FastAPI + Flutter + Google ADK (gemini-2.5-flash) + Firestore + BigQuery + Cloud Run. 47 files generated.
        </p>
        <div className="flex flex-wrap gap-2">
          {TAGS.map(t => <span key={t} className="font-mono text-xs border border-slate-300 px-3 py-1 bg-white">{t}</span>)}
        </div>
      </div>
    </section>
  );
}

function FileTreePanel() {
  return (
    <div className="md:row-span-2 border border-slate-200 bg-white overflow-hidden" data-testid="file-tree-panel">
      <div className="p-4 border-b border-slate-200 bg-slate-50">
        <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500">Repository</p>
        <h3 className="text-xl font-medium tracking-tight flex items-center gap-2">
          <TreeStructure size={18} weight="bold" className="text-[#002FA7]" /> File Tree
        </h3>
        <p className="text-xs text-slate-500 mt-1 font-mono">47 files generated</p>
      </div>
      <div className="p-2 max-h-[600px] overflow-y-auto">
        <TreeView items={FILE_TREE} />
      </div>
    </div>
  );
}

function TechStackSection() {
  return (
    <div className="md:col-span-2 lg:col-span-3" data-testid="tech-stack-section">
      <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Technology</p>
      <h3 className="text-xl font-medium tracking-tight mb-4">Stack Components</h3>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {TECH_STACK.map(t => (
          <div key={t.name} className="border border-slate-200 bg-white p-4 transition-all duration-200 hover:shadow-[4px_4px_0px_#0A0B0D] hover:-translate-y-0.5" data-testid={`tech-${t.name.toLowerCase().replace(/\s/g,'-')}`}>
            <div className="w-6 h-6 rounded-sm mb-2" style={{ backgroundColor: t.color, opacity: 0.25 }} />
            <span className="font-mono text-sm font-bold block">{t.name}</span>
            <span className="text-xs text-slate-500">{t.desc}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function PipelineSection() {
  return (
    <div className="md:col-span-2 lg:col-span-3" data-testid="pipeline-section">
      <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">ADK Agents</p>
      <h3 className="text-xl font-medium tracking-tight mb-4 flex items-center gap-2">
        <Brain size={20} weight="bold" className="text-[#002FA7]" /> Sequential Pipeline
      </h3>
      <div className="flex flex-col lg:flex-row items-stretch gap-0">
        {PIPELINE_STAGES.map((s, i) => (
          <React.Fragment key={s.name}>
            <div className="border border-slate-200 bg-white p-4 flex-1 transition-all duration-200 hover:shadow-[4px_4px_0px_#0A0B0D] hover:-translate-y-0.5" data-testid={`pipeline-stage-${i}`}>
              <div className="flex items-center gap-2 mb-2">
                <span className="w-6 h-6 flex items-center justify-center text-xs font-bold font-mono bg-[#002FA7] text-white">{i+1}</span>
                <span className="font-mono text-sm font-bold">{s.name}</span>
              </div>
              <p className="text-xs text-slate-600 mb-2">{s.desc}</p>
              <span className="font-mono text-[0.65rem] px-1.5 py-0.5 border border-slate-200 bg-slate-50">
                tool: <span className="text-[#002FA7] font-semibold">{s.tool}</span>
              </span>
            </div>
            {i < PIPELINE_STAGES.length - 1 && (
              <div className="flex items-center justify-center text-[#002FA7] py-2 lg:px-1">
                <ArrowRight size={18} weight="bold" className="hidden lg:block" />
                <CaretDown size={18} weight="bold" className="lg:hidden" />
              </div>
            )}
          </React.Fragment>
        ))}
      </div>
      <div className="mt-3 p-3 bg-slate-50 border border-slate-200">
        <p className="font-mono text-xs text-slate-600">
          <span className="font-bold text-[#002FA7]">Priority:</span>{" "}
          (urgency*0.4) + (log(pop+1)*0.3) + (log(reports+1)*0.15) + (min(hrs/72,1)*0.15)
        </p>
      </div>
    </div>
  );
}

function ApiRoutesSection() {
  return (
    <div className="md:col-span-3 lg:col-span-4" data-testid="api-routes-section">
      <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Backend</p>
      <h3 className="text-xl font-medium tracking-tight mb-4 flex items-center gap-2">
        <Lightning size={20} weight="bold" className="text-[#00C48C]" /> API Routes — {API_ROUTES.length} endpoints
      </h3>
      <div className="border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="p-3 font-mono text-xs font-bold text-slate-500 w-20">Method</th>
              <th className="p-3 font-mono text-xs font-bold text-slate-500">Path</th>
              <th className="p-3 font-mono text-xs font-bold text-slate-500 hidden sm:table-cell">Description</th>
            </tr>
          </thead>
          <tbody>
            {API_ROUTES.map((r, i) => (
              <tr key={i} className="border-b border-slate-100 hover:bg-slate-50" data-testid={`route-${i}`}>
                <td className="p-3"><MethodBadge method={r.method} /></td>
                <td className="p-3 font-mono text-xs">{r.path}</td>
                <td className="p-3 text-xs text-slate-500 hidden sm:table-cell">{r.desc}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ModelsSection() {
  return (
    <div className="md:col-span-2" data-testid="models-section">
      <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Data Schema</p>
      <h3 className="text-xl font-medium tracking-tight mb-4 flex items-center gap-2">
        <Database size={20} weight="bold" className="text-[#FFD000]" /> Pydantic v2 Models
      </h3>
      <div className="flex flex-col gap-2">
        {MODELS.map(m => <ModelCard key={m.name} model={m} />)}
      </div>
    </div>
  );
}

function SidebarInfo() {
  return (
    <div className="md:col-span-1 lg:col-span-2 flex flex-col gap-4" data-testid="sidebar-info">
      <div className="border border-slate-200 bg-white p-4" data-testid="scheduler-card">
        <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">APScheduler</p>
        <h3 className="text-lg font-medium tracking-tight mb-3 flex items-center gap-2">
          <Timer size={18} weight="bold" className="text-[#002FA7]" /> Cron Jobs
        </h3>
        <div className="space-y-3">
          <div className="border border-slate-200 p-3">
            <span className="font-mono text-xs font-bold">compute_volunteer_scores</span>
            <p className="text-xs text-slate-500 mt-1">Midnight IST daily</p>
          </div>
          <div className="border border-slate-200 p-3">
            <span className="font-mono text-xs font-bold">generate_weekly_report</span>
            <p className="text-xs text-slate-500 mt-1">Monday 6 AM IST</p>
          </div>
        </div>
      </div>

      <div className="border border-slate-200 bg-white p-4" data-testid="enums-card">
        <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Enumerations</p>
        <div className="space-y-2 text-xs">
          {Object.entries(ENUMS).map(([name, values]) => (
            <div key={name}>
              <span className="font-mono font-bold">{name}:</span>
              <div className="flex flex-wrap gap-1 mt-1">
                {values.map(v => <span key={v} className="font-mono text-[0.65rem] px-1.5 py-0.5 border border-slate-200 bg-slate-50">{v}</span>)}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="border border-slate-200 bg-white p-4" data-testid="cicd-card">
        <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Deployment</p>
        <h3 className="text-lg font-medium tracking-tight mb-3 flex items-center gap-2">
          <CloudArrowUp size={18} weight="bold" className="text-[#00C48C]" /> CI/CD Pipeline
        </h3>
        <div className="text-xs space-y-1 text-slate-600">
          {CICD_STEPS.map(s => (
            <p key={s} className="flex items-center gap-1">
              <CaretRight size={10} weight="bold" className="text-[#002FA7] shrink-0" /> {s}
            </p>
          ))}
        </div>
      </div>
    </div>
  );
}

function EnvVarsSection() {
  return (
    <div className="md:col-span-3 lg:col-span-4" data-testid="env-vars-section">
      <p className="uppercase text-[0.7rem] tracking-[0.2em] font-bold text-slate-500 mb-1">Configuration</p>
      <h3 className="text-xl font-medium tracking-tight mb-4 flex items-center gap-2">
        <Terminal size={20} weight="bold" /> Environment Variables
        <span className="text-xs font-mono text-slate-400">.env.example</span>
      </h3>
      <div className="bg-[#0A0B0D] text-[#4ADE80] font-mono text-xs leading-relaxed p-6 border border-slate-700 overflow-x-auto" data-testid="env-terminal">
        <pre className="whitespace-pre-wrap">{ENV_VARS}</pre>
      </div>
    </div>
  );
}

function Footer() {
  return (
    <footer className="mt-12 py-6 border-t border-slate-200 text-center" data-testid="footer">
      <p className="text-xs font-mono text-slate-400">
        CommunityPulse Nova Rangers — Google Solution Challenge 2026 — Madhya Pradesh, India
      </p>
    </footer>
  );
}

export default App;
