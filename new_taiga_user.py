import json
import secrets
import string
import aiohttp
import collections
import asyncio


alphabet = string.ascii_letters + string.digits


class Taiga:
    def __init__(self, url, login, password):
        self.url = f"{url}/api/v1"
        self.login = login
        self.password = password
        self.auth = {}

    async def get_auth(self, login=None, password=None, id=False):
        if not login and not password:
            data = {"username": self.login, "password": self.password, "type": 'normal'}
            root_auth = await self.post(f'/auth', data=data, headers={})
            self.auth = {"Authorization": f"Bearer {root_auth['auth_token']}"}
            return True

        data = {"username": login, "password": password, "type": 'normal'}
        a = await self.post(f'/auth', data=data, headers={})
        d = a.json()
        if id:
            return {"Authorization": f"Bearer {d['auth_token']}"}, d['id']
        return {"Authorization": f"Bearer {d['auth_token']}"}

    async def post(self, path, params=None, **kwargs):
        if params is None:
            params = {}
        if 'headers' not in kwargs:
            kwargs['headers'] = self.auth
        async with aiohttp.ClientSession() as session:
            async with session.post(f"{self.url}{path}", params=params, **kwargs) as response:
                if response.status not in range(200, 300):
                    raise TaigaError
                loads = lambda s: json.loads(s, object_pairs_hook=collections.OrderedDict)
                res = await response.json(loads=loads)
                return res

    async def get(self, path, params=None, **kwargs):
        if params is None:
            params = {}
        if 'headers' not in kwargs:
            kwargs['headers'] = self.auth
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.url}{path}", params=params, **kwargs) as response:
                if response.status not in range(200, 300):
                    raise TaigaError
                loads = lambda s: json.loads(s, object_pairs_hook=collections.OrderedDict)
                res = await response.json(loads=loads)
                return res

    async def join_to_project(self, project, role, email):
        project_data = {
            "project": project,
            "role": role,
            "username": email
        }
        join = await self.post('/memberships', data=project_data)
        return join

    async def create_user(self, person, project_name, role_name, photo=None):
        password = ''.join(secrets.choice(alphabet) for i in range(8))

        register_data = {'accepted_terms': ['True'], 'username': [f'{person["login"]}'],
                         'full_name': [f'{person["full_name"]}'],
                         'email': [f'{person["email"]}'], 'password': [password], 'type': ['public']}
        register = await self.post('/auth/register', data=register_data)
        if register:
            print(f"Регистрация успешна. Пароль: {password}")
            auth_token = register['auth_token']
            head = {"Authorization": f"Bearer {auth_token}"}
            if photo:
                try:
                    with open(f'{photo}', 'rb') as inf:
                        photo = inf.read()
                    change_avatar = await self.post("/users/change_avatar", files={"avatar": photo}, headers=head)
                    print(f"Аватар обновлен")
                except Exception:
                    print(f"Аватар не обновлен")
            projects = await self.get('/projects')
            created = False
            for project in projects:
                if project['name'] == project_name:
                    roles = await self.get(f'/roles?project={project["id"]}')
                    for role in roles:
                        if role['name'] == role_name:
                            await self.join_to_project(project['id'], role['id'], person['email'])
                            created = True
                            break
                    if created:
                        break
            print("Пользователь добавлен")
        else:
            print('Пользователь не добавлен')



class TaigaError(Exception):
    """"""


taiga = Taiga('https://boards.calculate.ru', 'admin', 'uRW4oVw0QS4kQ')


async def fun():
    await taiga.get_auth()
    res = await taiga.create_user({"login": input('login: '), "full_name": input('Имя: '), "email": input('email: ')},
                                  input('К какому проекту добавить: '), input('Роль на проекте: '), input('полный путь к фотографии: '))
    return res


asyncio.run(fun())
