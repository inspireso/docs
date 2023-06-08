#!/usr/bin/env python3

# -*- coding: utf-8 -*-

import requests

headers = {'PRIVATE-TOKEN': '7XwHcLhgUmsiwyE8FdY9'}


def get_repositories_by_project(id):
    res = requests.get(
        url="https://git.uutaka.com/api/v4/projects/{}/registry/repositories".format(
            id
        ),
        headers=headers,
    )
    return res.json()


def get_repositories_by_group(id):
    res = requests.get(
        url="https://git.uutaka.com/api/v4/groups/{}/registry/repositories?tags=1&tags_count=true".format(
            id
        ),
        headers=headers,
    )
    return res.json()


def del_repositories(project_id, id):
    res = requests.delete(
        url="https://git.uutaka.com/api/v4//projects/{}/registry/repositories/{}".format(
            project_id, id
        ),
        headers=headers,
    )
    print(res.json())


def del_repositories_by_group(id):
    repo_list = get_repositories_by_group(46)
    for repo in repo_list:
        del_repositories(repo['project_id'], repo['id'])
        print(repo)


if __name__ == '__main__':
    # get_repositories_by_project(175)
    # repo_list = get_repositories_by_group(114)
    del_repositories_by_group(143)
