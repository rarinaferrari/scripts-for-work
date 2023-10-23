package main

import (
	"context"
	"fmt"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
)

func main() {
	// Создаем клиент Docker
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		panic(err)
	}

	// Получаем список всех контейнеров
	containers, err := cli.ContainerList(context.Background(), types.ContainerListOptions{All: true})
	if err != nil {
		panic(err)
	}

	// Удаляем все контейнеры
	for _, container := range containers {
		err := cli.ContainerRemove(context.Background(), container.ID, types.ContainerRemoveOptions{Force: true})
		if err != nil {
			fmt.Printf("Failed to remove container %s: %s\n", container.ID, err)
		} else {
			fmt.Printf("Removed container %s\n", container.ID)
		}
	}

	// Получаем список всех образов
	images, err := cli.ImageList(context.Background(), types.ImageListOptions{All: true})
	if err != nil {
		panic(err)
	}

	// Удаляем все образы
	for _, image := range images {
		_, err := cli.ImageRemove(context.Background(), image.ID, types.ImageRemoveOptions{Force: true})
		if err != nil {
			fmt.Printf("Failed to remove image %s: %s\n", image.ID, err)
		} else {
			fmt.Printf("Removed image %s\n", image.ID)
		}
	}

	// Получаем список всех томов
	volumeFilters := filters.NewArgs()
	volumeFilters.Add("dangling", "false") // только неиспользуемые тома
	volumes, err := cli.VolumeList(context.Background(), volumeFilters)
	if err != nil {
		panic(err)
	}

	// Удаляем все неиспользуемые тома
	for _, volume := range volumes.Volumes {
		err := cli.VolumeRemove(context.Background(), volume.Name, true)
		if err != nil {
			fmt.Printf("Failed to remove volume %s: %s\n", volume.Name, err)
		} else {
			fmt.Printf("Removed volume %s\n", volume.Name)
		}
	}

