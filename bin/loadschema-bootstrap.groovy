//action

try {
    System.out.println('\n\n\n\nABOUT TO LOAD /opt/graphdb/conf/graph-schema.json\n\n\n\n\n')
    String retVal = loadSchema(graph,'/opt/graphdb/conf/graph-schema.json')
    
    System.out.println("results after loading /opt/graphdb/conf/graph-schema.json: ${retVal}\n\n\n\n\n")

} catch (e) {
    e.printStackTrace()
}

