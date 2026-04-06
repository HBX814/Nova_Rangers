import React, { useState, useCallback } from "react";
import { CaretRight, CaretDown, Folder, File } from "@phosphor-icons/react";

// Flatten tree into a list with depth tracking
function flattenTree(nodes, depth, result) {
  for (const node of nodes) {
    result.push({ ...node, depth, hasChildren: !!(node.children && node.children.length) });
    if (node.children) {
      flattenTree(node.children, depth + 1, result);
    }
  }
  return result;
}

export function TreeView({ items }) {
  const flat = flattenTree(items, 0, []);
  const [collapsed, setCollapsed] = useState({});

  const toggle = useCallback((name) => {
    setCollapsed(prev => ({ ...prev, [name]: !prev[name] }));
  }, []);

  // Track which folders are collapsed to hide their children
  const visible = [];
  const hiddenPrefixes = [];

  for (const item of flat) {
    // Check if this item is hidden by a collapsed parent
    const isHidden = hiddenPrefixes.some(prefix =>
      item.depth > prefix.depth
    );
    if (isHidden) {
      // Also propagate hiding if this is a folder
      if (item.hasChildren && collapsed[item.name]) {
        hiddenPrefixes.push(item);
      }
      continue;
    }
    visible.push(item);
    if (item.hasChildren && collapsed[item.name]) {
      hiddenPrefixes.push(item);
    }
  }

  return (
    <div className="font-mono text-xs">
      {visible.map((item, i) => (
        <div
          key={`${item.name}-${i}`}
          className="py-0.5 flex items-center gap-1 cursor-pointer hover:bg-slate-50 px-2"
          style={{ paddingLeft: item.depth * 16 + 8 }}
          onClick={() => item.hasChildren && toggle(item.name)}
          data-testid={`tree-item-${i}`}
        >
          {item.hasChildren ? (
            collapsed[item.name] ? <CaretRight size={12} weight="bold" /> : <CaretDown size={12} weight="bold" />
          ) : <span className="w-3 inline-block" />}
          {item.hasChildren ? (
            <Folder size={14} weight="fill" className="text-[#002FA7] shrink-0" />
          ) : (
            <File size={14} className="text-slate-400 shrink-0" />
          )}
          <span className={item.hasChildren ? "text-[#002FA7] font-semibold" : "text-slate-600"}>
            {item.name}
          </span>
        </div>
      ))}
    </div>
  );
}

export function MethodBadge({ method }) {
  const cls = {
    GET: "bg-[#0047FF] text-white",
    POST: "bg-[#00C48C] text-white",
    PATCH: "bg-[#FFD000] text-[#0A0B0D]",
    DELETE: "bg-[#FF3B30] text-white",
  };
  return (
    <span className={`font-mono text-[0.65rem] font-bold px-2 py-0.5 inline-block ${cls[method] || "bg-slate-400 text-white"}`}>
      {method}
    </span>
  );
}

export function ModelCard({ model }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="border border-slate-200 bg-white">
      <button
        className="w-full flex items-center justify-between p-3 text-left hover:bg-slate-50"
        onClick={() => setOpen(!open)}
        data-testid={`model-toggle-${model.name.toLowerCase()}`}
      >
        <span className="font-mono text-sm font-bold">{model.name}</span>
        <span className="text-xs text-slate-400">{model.fields.length} fields</span>
      </button>
      {open && (
        <div className="px-3 pb-3 border-t border-slate-100 pt-2 flex flex-wrap gap-1">
          {model.fields.map((f, i) => (
            <span key={i} className="font-mono text-[0.65rem] px-1.5 py-0.5 border border-slate-200 bg-slate-50 text-slate-600">
              {f}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
