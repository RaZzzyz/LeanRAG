#生成json文件{"answer":""}
import re
import json
import jsonlines
import argparse
import os
import time
import copy
import yaml
from openai import OpenAI
from query_graph import deepseepk_model_if_cache,embedding,field,query_graph
from tools.utils import write_jsonl

DATASET = "mix"
if DATASET == "mix":
    MAX_QUERIES = 130
elif DATASET == "cs" or DATASET == "agriculture" or DATASET == "legal":
    MAX_QUERIES = 100

with open('config.yaml', 'r') as file:
    config = yaml.safe_load(file)
def generate_answer(query_file, global_config ,output_file_path):
    queries = []
    answers= []
    with open(query_file, "r", encoding="utf-8") as infile:
        for line_number, line in enumerate(infile, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                json_obj = json.loads(line)
                query = json_obj.get("query")
                queries.append(query)
            except json.JSONDecodeError as e:
                print(
                f"JSON decoding error in file {query_file} at line {line_number}: {e}"
                )
    queries = queries[:MAX_QUERIES]
    for query in queries:
        response = query_graph(
            query=query,
            global_config=global_config,
        )
        answers.append({
            "answer": response,
        })
    write_jsonl(answers, output_file_path)
if __name__ == "__main__":
    WORKING_DIR="test_data"
    global_config={}
    global_config['use_llm_func']=deepseepk_model_if_cache
    global_config['embeddings_func']=embedding
    global_config["special_community_report_llm_kwargs"]=field(
        default_factory=lambda: {"response_format": {"type": "json_object"}}
    )
    global_config['working_dir']=WORKING_DIR
    generate_answer("query_file.jsonl", global_config, "answer_file.jsonl")