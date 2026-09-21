import json,sys
def txt(inl):
    out=""
    for i in inl or []:
        t=i.get("type")
        if t=="text": out+=i["text"]
        elif t in("emphasis","strong","newTerm"): out+=txt(i.get("inlineContent"))
        elif t=="codeVoice": out+="`"+i["code"]+"`"
        elif t=="reference": out+="["+i.get("identifier","").split("/")[-1]+"]"
        elif "inlineContent" in i: out+=txt(i["inlineContent"])
    return out
def walk(blocks,d=0):
    for b in blocks or []:
        t=b.get("type")
        if t=="heading": print("\n"+"#"*b.get("level",2)+" "+b["text"])
        elif t=="paragraph": print(txt(b["inlineContent"]))
        elif t in("unorderedList","orderedList"):
            for it in b["items"]:
                print("- ",end=""); walk(it["content"],d+1)
        elif t=="aside": print("> ",end=""); walk(b["content"])
        elif t=="table":
            for r in b.get("rows",[]): print(" | ".join(" ".join(txt(c.get("inlineContent")) if c.get("type")=="paragraph" else "" for c in cell) for cell in r))
        elif "content" in b: walk(b["content"],d)
j=json.load(open(sys.argv[1]))
for s in j.get("primaryContentSections",[]): walk(s.get("content"))
